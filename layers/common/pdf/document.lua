-- Instantiate explicit Markdown templates from a verified source snapshot.
local stringify = pandoc.utils.stringify
local placeholder = '%{%{%s*([%w_.-]+)%s*%}%}'

local function code(value)
  return pandoc.Code(tostring(value))
end

local function breakable_hash(value)
  local label = pandoc.List()
  for index = 1, #value do
    if index > 1 then label:insert(pandoc.RawInline('latex', '\\allowbreak{}')) end
    label:insert(code(value:sub(index, index)))
  end
  return label
end

local function latex(inlines)
  return pandoc.write(pandoc.Pandoc({pandoc.Plain(inlines)}), 'latex'):gsub('%s+$', '')
end

local function statement_kind(header)
  for _, class in ipairs(header.classes) do
    if class == 'definition' or class == 'theorem' or class == 'lemma' or class == 'proof' then
      assert(header.level == 2, 'Statements must be second-level headings')
      return class
    end
  end
end

local function repository_path(path)
  local parts = {}
  for part in path:gmatch('[^/]+') do
    if part == '..' then
      assert(#parts > 0, 'Link escapes the repository: ' .. path)
      table.remove(parts)
    elseif part ~= '.' then
      parts[#parts + 1] = part
    end
  end
  return table.concat(parts, '/')
end

local function read_markdown(markdown)
  -- Pandoc 3.1 needs GitHub's inline math delimiters normalized.
  markdown = markdown:gsub('%$`(.-)`%$', '$%1$')
  return pandoc.read(markdown, 'markdown+tex_math_dollars+gfm_auto_identifiers')
end

local function attach_displays(blocks)
  local joined = pandoc.List()
  for _, block in ipairs(blocks) do
    local previous = joined[#joined]
    local display = block.t == 'Para' and #block.content == 1
      and block.content[1].t == 'Math' and block.content[1].mathtype == 'DisplayMath'
    local last = previous and previous.t == 'Para' and previous.content[#previous.content]
    if display and last and not (last.t == 'Math' and last.mathtype == 'DisplayMath') then
      -- A display continues the preceding prose paragraph. Ending that paragraph
      -- first makes TeX insert an empty text line above the equation.
      local content = previous.content
      content:insert(pandoc.SoftBreak())
      content:extend(block.content)
      joined[#joined] = pandoc.Para(content)
    else
      joined:insert(block)
    end
  end
  return joined
end

function Pandoc(document)
  local meta = document.meta
  local paper = meta.paper == true
  local revision, short = stringify(meta.revision), stringify(meta.short_revision)
  assert(revision:match('^[0-9a-f]+$') and #revision == 40, 'Expected a full Git SHA')
  assert(short == revision:sub(1, 8), 'Expected an eight-character revision identifier')
  local repository_name = stringify(meta.repository)
  local repository = 'https://github.com/' .. repository_name
  local github = repository .. '/blob/' .. revision .. '/'
  local raw = 'https://raw.githubusercontent.com/' .. repository_name .. '/' .. revision .. '/'
  local publication = 'https://orderly.cameron1729.xyz/proofs/' .. revision .. '/'
  local kind = stringify(meta.document_kind)
  assert(kind == 'correctness' or kind == 'theory', 'Unknown document kind')
  local snapshot = stringify(meta.snapshot_root)
  assert(snapshot ~= '', 'Expected a pinned source snapshot')

  local values = {
    ['revision.short'] = short,
    ['revision.full'] = revision,
    ['revision.url'] = repository .. '/tree/' .. revision,
    ['revision.math'] = '{\\mathtt{' .. short .. '}}',
    ['verification.run'] = stringify(meta.verification_run),
    ['verification.attempt'] = stringify(meta.verification_attempt),
    ['verification.url'] = stringify(meta.verification_url),
    ['publication.url'] = stringify(meta.publication_url)
  }
  for _, job in ipairs(meta.jobs) do
    local layer = stringify(job.name):match('^Layer (%d+)$')
    assert(layer and stringify(job.conclusion) == 'success', 'Expected a successful layer check')
    values['verification.layers.' .. layer .. '.id'] = stringify(job.id)
    values['verification.layers.' .. layer .. '.attempt'] = stringify(job.run_attempt)
    values['verification.layers.' .. layer .. '.url'] = stringify(job.html_url)
  end
  for key, path in pairs({
    theory = 'layers/0-theory/THEORY.md',
    correctness = 'layers/CORRECTNESS.md'
  }) do
    local definition = meta.documents[key]
    assert(definition and stringify(definition.path) == path, 'Unexpected document source')
    local digest, approved = stringify(definition.digest), stringify(definition.approved_digest)
    assert(digest:match('^[0-9a-f]+$') and #digest == 64 and digest == approved,
      'The source SHA-256 must match its independently approved target')
    local prefix = 'documents.' .. key .. '.'
    values[prefix .. 'path'] = path
    values[prefix .. 'sha256'] = digest
    values[prefix .. 'source_url'] = github .. path
    values[prefix .. 'raw_url'] = raw .. path
    values[prefix .. 'approval_url'] = stringify(definition.approval_url)
  end

  local function read_source(path)
    assert(repository_path(path) == path and path:sub(1, 1) ~= '/', 'Invalid source path')
    assert(meta.snapshot_digests[path], 'Source is not in the verified snapshot: ' .. path)
    local file = assert(io.open(snapshot .. '/' .. path, 'rb'))
    local contents = file:read('*a')
    file:close()
    return contents
  end

  if kind == 'correctness' then
    assert(meta.runtime, 'Missing verified PHP runtime profile')
    values['runtime.version'] = stringify(meta.runtime.version)
    values['runtime.optimization_level'] = stringify(meta.runtime.optimization_level)
    values['runtime.profile_url'] = github .. 'layers/common/php/profile.json'
    values['runtime.instructions'] = read_source('layers/common/php/expected-opcodes.txt'):gsub('%s+$', '')
  end

  local function definition_sections(path)
    local sections = {introduction = pandoc.List()}
    local section, titled = 'introduction', false
    for _, block in ipairs(read_markdown(read_source(path)).blocks) do
      if block.t == 'Header' and block.level == 1 then
        assert(not titled, 'Expected one definition title')
        titled = true
      elseif block.t == 'Header' and block.level == 2 then
        section = block.identifier
        assert(not sections[section], 'Duplicate definition section: ' .. section)
        sections[section] = pandoc.List()
      else
        sections[section]:insert(block)
      end
    end
    assert(titled, 'Missing definition title')
    if #sections.introduction == 0 then sections.introduction = nil end
    return sections
  end

  local sources, included, targets, used, statements = {}, {}, {}, {}, {}
  for _, source in ipairs(meta.sources) do
    local path, id, source_kind = stringify(source.path), stringify(source.id), stringify(source.kind)
    assert(source_kind == 'template' or source_kind == 'document', 'Expected an explicit source kind')
    local markdown = read_source(path)
    local definition = source.definition and stringify(source.definition)
    if definition then
      assert(definition == values['documents.correctness.path'],
        'The shared template must include the approved correctness definition')
    end
    if source_kind == 'template' then
      markdown = markdown:gsub(placeholder, function(name)
        if definition and name:match('^correctness%.') then return '{{' .. name .. '}}' end
        local value = values[name]
        assert(value and value ~= '', 'Unknown or missing template value: ' .. name)
        used[name] = true
        return value
      end)
    else
      assert(not definition, 'Only templates may instantiate a definition')
    end

    local parsed, anchors, titled = read_markdown(markdown), {[''] = id}, false
    local function namespace_anchor(element, title)
      local original = element.identifier
      element.identifier = title and id or id .. '-' .. original
      anchors[original] = element.identifier
      assert(not targets[element.identifier], 'Duplicate document anchor: ' .. element.identifier)
      targets[element.identifier] = true
      return element
    end
    parsed = parsed:walk({
      Header = function(header)
        if header.level == 1 then
          assert(not titled, 'Expected one document title: ' .. path)
          titled = true
        end
        header = namespace_anchor(header, header.level == 1)
        if source_kind == 'template' then statements[header.identifier] = statement_kind(header) end
        return header
      end,
      Div = function(div)
        if div.identifier ~= '' then return namespace_anchor(div) end
      end
    })
    assert(titled, 'Missing document title: ' .. path)
    included[path] = anchors
    if definition then included[definition] = anchors end
    sources[#sources + 1] = {
      path = path, id = id, kind = source_kind, document = parsed,
      definition = definition, sections = definition and definition_sections(definition),
      page_break = source.page_break == true
    }
  end

  local function statement_reference(element)
    local id = element.target:match('^#(.+)$')
    local environment = statements[id]
    if environment and environment ~= 'proof' then
      local name = environment:gsub('^%l', string.upper)
      if stringify(element.content) == name then
        return pandoc.RawInline('latex', '\\hyperref[' .. id .. ']{' .. name .. '~\\ref*{' .. id .. '}}')
      end
    end
    return element
  end

  local function resolve_link(origin, element)
    local label = stringify(element.content)
    if element.target == values['revision.url'] and (label == revision or label == short) then
      -- Preserve the chosen full or short identifier, typeset in monospace.
      element.content = {code(label)}
      return element
    end
    if element.target:match('^[%a][%w+.-]*:') or element.target:sub(1, 2) == '//' then return end
    if element.target:sub(1, 1) == '#' and targets[element.target:sub(2)] then
      return statement_reference(element)
    end
    local path, fragment = element.target:match('^([^#]*)#?(.*)$')
    path = path == '' and origin or repository_path(pandoc.path.directory(origin) .. '/' .. path)
    if included[path] then
      element.target = '#' .. assert(included[path][fragment], 'Unknown included anchor: ' .. element.target)
    elseif path == 'layers/0-theory/THEORY.md' then
      element.target = publication .. 'theory-0.pdf'
    else
      element.target = github .. path .. (fragment ~= '' and '#' .. fragment or '')
    end
    return statement_reference(element)
  end

  local function instantiate_definition(blocks, origin)
    -- A correctness.* inclusion explicitly binds the definition's parameter r.
    -- Its prose and laws are included from the authoritative document, not copied
    -- into a second definition. No other source receives this parameter binding.
    local instantiated = pandoc.Pandoc(blocks):walk({
      Math = function(math)
        if math.mathtype == 'InlineMath' and math.text:match('^%s*r%s*$') then
          return pandoc.Link({code(short)}, values['revision.url'])
        end
        math.text = math.text:gsub('\\?[%a]+', function(token)
          return token == 'r' and values['revision.math'] or token
        end)
        return math
      end,
      Link = function(element) return resolve_link(origin, element) end
    }).blocks
    return instantiated
  end

  local blocks = pandoc.List()
  if not paper then blocks:insert(pandoc.RawBlock('latex', '\\tableofcontents\n\\clearpage')) end
  for _, source in ipairs(sources) do
    local rendered = source.document
    if source.sections then
      local sections_used = {}
      rendered = rendered:walk({Para = function(para)
        local section = stringify(para):match('^{{correctness%.([%w_-]+)}}$')
        if not section then return end
        assert(source.sections[section], 'Unknown definition section: ' .. section)
        assert(not sections_used[section], 'Repeated definition section: ' .. section)
        sections_used[section] = true
        return instantiate_definition(source.sections[section], source.definition)
      end})
      for section in pairs(source.sections) do
        assert(sections_used[section], 'The template omits a definition section: ' .. section)
      end
    end
    if source.kind == 'template' then
      rendered = rendered:walk({
        Str = function(str)
          assert(not str.text:match(placeholder), 'Unexpanded template value: ' .. str.text)
        end
      })
    end
    rendered = rendered:walk({
      Link = function(element) return resolve_link(source.path, element) end,
      Math = function(math)
        -- Typeset the definition relation as one centred colon-equals symbol.
        math.text = math.text:gsub(':%s*=%s*', '\\coloneq ')
        if paper then
          -- Math punctuation already supplies thin spacing after a comma.
          -- Retain continuation indents and gaps between separate equations.
          math.text = math.text:gsub(',%s*\\quad%f[^%a]', ',')
        end
        return math
      end
    })
    if paper then
      rendered = rendered:walk({
        Code = function(element)
          if element.text == revision or (#element.text == 64 and element.text:match('^[0-9a-f]+$')) then
            return breakable_hash(element.text)
          end
        end,
        CodeBlock = function(block)
          if block.classes:includes('centered') then
            assert(not block.text:find('\\end{BVerbatim}', 1, true),
              'A centered code block cannot contain its verbatim terminator')
            -- Box the literal text at its natural width, then centre the box.
            return pandoc.RawBlock('latex', '\\begin{center}\n\\begin{BVerbatim}\n' ..
              block.text .. '\n\\end{BVerbatim}\n\\end{center}')
          end
        end
      })
    end
    if source.page_break then blocks:insert(pandoc.RawBlock('latex', '\\clearpage')) end
    -- Marked headings delimit native LaTeX statements. Their counters, labels and
    -- references are resolved by LaTeX, not hard-coded in the Markdown templates.
    local environment, keep_together, remaining_blocks
    local function close_statement()
      assert(not remaining_blocks or remaining_blocks == 0,
        'The statement has fewer blocks than its statement-blocks attribute')
      if environment then blocks:insert(pandoc.RawBlock('latex', '\\end{' .. environment .. '}')) end
      if keep_together then blocks:insert(pandoc.RawBlock('latex', '\\end{minipage}\\par')) end
      environment = nil
      keep_together = false
      remaining_blocks = nil
    end
    for _, block in ipairs(rendered.blocks) do
      if block.t == 'Header' and block.level <= 2 then close_statement() end
      local statement = block.t == 'Header' and statements[block.identifier]
      if statement then
        environment = statement
        keep_together = block.classes:includes('keep-together')
        -- Templates may end the italic statement before its supporting prose,
        -- without changing or duplicating the approved source definitions.
        local count = block.attributes['statement-blocks']
        if count then
          assert(count:match('^[1-9][0-9]*$'), 'Expected a positive statement-blocks count')
          remaining_blocks = tonumber(count)
        end
        local title = latex(block.content)
        local opening = '\\begin{' .. statement .. '}'
        if keep_together then opening = '\\par\\noindent\\begin{minipage}{\\linewidth}\n' .. opening end
        if statement ~= 'proof' then
          local name = statement:gsub('^%l', string.upper)
          opening = opening .. '[' .. title .. ']\\label{' .. block.identifier .. '}'
          if not paper then
            opening = opening .. '\n\\addcontentsline{toc}{subsection}{' .. name ..
              '~\\the' .. statement .. ': ' .. title .. '}'
          end
        end
        blocks:insert(pandoc.RawBlock('latex', opening .. '\n\\hypertarget{' .. block.identifier .. '}{}'))
      else
        blocks:insert(block)
        if remaining_blocks then
          remaining_blocks = remaining_blocks - 1
          if remaining_blocks == 0 then close_statement() end
        end
      end
    end
    close_statement()
  end

  if kind == 'correctness' then
    for _, name in ipairs({
      'revision.short', 'revision.full', 'revision.url',
      'verification.url', 'verification.layers.0.url', 'publication.url',
      'runtime.version', 'runtime.profile_url', 'runtime.instructions',
      'documents.theory.sha256', 'documents.correctness.sha256',
      'documents.theory.raw_url', 'documents.correctness.raw_url'
    }) do
      assert(used[name], 'The proof template must present ' .. name)
    end
  end
  -- Join only after statement-blocks has been counted and environment boundaries
  -- inserted, so equations cannot move into or out of a statement.
  if paper then blocks = attach_displays(blocks) end
  return pandoc.Pandoc(blocks, meta)
end
