# Minimal markdown-to-HTML renderer for the public privacy policy page.
# Supports exactly what docs/PRIVACY.md uses: headings, tables, bullet lists,
# bold and links. Content is HTML-escaped before conversion so the document
# can never inject markup into the page.
class MarkdownRenderer
  def initialize(markdown)
    @text = markdown.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end

  def to_html
    html = headings
    html = inline(html)
    wrap_blocks(html)
  end

  private

  def headings
    out = @text.dup
    out = out.gsub(/^### (.+)$/) { "<h3>#{Regexp.last_match(1)}</h3>" }
    out = out.gsub(/^## (.+)$/) { "<h2>#{Regexp.last_match(1)}</h2>" }
    out.gsub(/^# (.+)$/) { "<h1>#{Regexp.last_match(1)}</h1>" }
  end

  def inline(text)
    text = text.gsub(/\*\*(.+?)\*\*/) { "<strong>#{Regexp.last_match(1)}</strong>" }
    linkify(text)
  end

  def linkify(text)
    text.gsub(/\[(.+?)\]\((.+?)\)/) do
      %(<a href="#{Regexp.last_match(2)}" target="_blank" rel="noopener">#{Regexp.last_match(1)}</a>)
    end
  end

  def wrap_blocks(html)
    out = []
    table_buffer = []

    html.lines.each do |line|
      if table_row?(line)
        table_buffer << line.strip
        next
      end

      out << render_table(table_buffer) unless table_buffer.empty?
      table_buffer = []

      out << wrap_paragraph(line.strip)
    end
    out << render_table(table_buffer) unless table_buffer.empty?

    out.join("\n")
  end

  def table_row?(line)
    line.strip.start_with?("|") && line.include?("|")
  end

  def wrap_paragraph(stripped)
    if stripped.start_with?("- ")
      "<li>#{stripped.delete_prefix('- ')}</li>"
    elsif stripped.empty?
      ""
    else
      "<p>#{stripped}</p>"
    end
  end

  def render_table(rows)
    body = rows.grep_v(/\|[- ]+\|/)
    cells = ->(row) { row.split("|").map(&:strip).reject(&:empty?) }
    thead = "<thead><tr>#{cells.call(body.first).map { |c| "<th>#{c}</th>" }.join}</tr></thead>"
    tbody = "<tbody>#{body.drop(1).map { |r| "<tr>#{cells.call(r).map { |c| "<td>#{c}</td>" }.join}</tr>" }.join}</tbody>"
    "<table>#{thead}#{tbody}</table>"
  end
end
