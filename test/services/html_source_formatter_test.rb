require "test_helper"

class HtmlSourceFormatterTest < ActiveSupport::TestCase
  test "places nested block elements on indented lines" do
    source = '<section><h2>Заголовок</h2><ul><li>Первый</li><li>Второй</li></ul></section>'

    assert_equal <<~HTML.chomp, HtmlSourceFormatter.call(source)
      <section>
        <h2>Заголовок</h2>
        <ul>
          <li>Первый</li>
          <li>Второй</li>
        </ul>
      </section>
    HTML
  end

  test "keeps inline text together" do
    source = '<p>Текст <strong>с выделением</strong> и <a href="/link">ссылкой</a>.</p>'

    assert_equal source, HtmlSourceFormatter.call(source)
  end

  test "does not alter whitespace inside preformatted blocks" do
    pre = "<pre><code>if (ready) {\n  run();\n}</code></pre>"
    source = "<section>#{pre}<p>После кода</p></section>"
    formatted = HtmlSourceFormatter.call(source)

    assert_includes formatted, pre
    assert_equal pre, formatted[/<pre>.*<\/pre>/m]
    assert_includes formatted, "  <p>После кода</p>"
  end
end
