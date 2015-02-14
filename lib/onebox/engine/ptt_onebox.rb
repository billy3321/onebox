module Onebox
  module Engine
    class PttOnebox
      include Engine
      include LayoutSupport

      matches_regexp(/^(https?:\/\/)(www.ptt.cc\/)(.)+\/?$/)

      private

      def data
        source_uri = URI.parse(link)
        if source_uri.path.include?('Gossiping')
          agent = Mechanize.new
          html = agent.post('https://www.ptt.cc/ask/over18', {from: source_uri.path, yes: 'yes'})
          raw_html = Nokogiri::HTML(html.body)
        else
          agent = Mechanize.new
          html = agent.get(link)
          raw_html = Nokogiri::HTML(html.body)
        end
        info_section = raw_html.css('div#main-container div#main-content.bbs-screen.bbs-content')[0]
        pushes = info_section.css('div.push')
        date_string = info_section.css('div.article-metaline span.article-meta-value')[2].text
        date = Time.parse(date_string).strftime('%Y-%m-%d %H:%M')
        info_section.search('.//div').remove
        content = info_section.text.gsub("\n", '<br />')
        title = raw_html.at('meta[property="og:title"]')['content']
        result = {
          link: link,
          title: title,
          description: content,
          date: date,
          comments: []
        }
        comment = nil
        pushes.each do |p|
          comment_author = p.css('span.push-userid')[0].text
          if comment and comment[:author] == comment_author
            comment[:content] << "<br />" + p.css('span.push-content')[0].text[2..-1]
          else
            comment = {author: comment_author, content: ""}
            result[:comments] << comment
            comment[:author] = comment_author
            comment[:content] = p.css('span.push-content')[0].text[2..-1]
          end
        end
        return result
      end
    end
  end
end
