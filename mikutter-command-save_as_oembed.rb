#coding: utf-8

Plugin.create(:"mikutter-command-sava_as_image") {
  require File.join(File.dirname(__FILE__), "dirselect.rb")

  UserConfig[:save_as_oembed_folder] ||= Dir.home

  # コマンド
  command(:save_as_oembed,
        :name => _("HTMLとして保存"),
        :condition => lambda { |opt| Plugin::Command[:HasMessage] && !opt.messages.any? { |_| _.system? } },
        :visible => true,
        :role => :timeline) { |opt|

    begin
      requests = opt.messages.map { |message|
        (Service.primary.twitter/"statuses/oembed").json(:id => message[:id], :omit_script => "true")
      }

      Deferred.when(*requests).next { |results|
        html = results.map { |_| _[:html] }.map { |html| html.gsub(/src\=\"\/\//, "src=\"http://") }.join("\n")

        filename = "#{opt.messages.first.user[:idname]}-#{opt.messages.first[:id_str]}.html"

        File.open(File.join(UserConfig[:save_as_oembed_folder], filename), "wt") { |fp|
          fp.puts("<html lang=\"ja\">")
          fp.puts("<body>")
          fp.puts("<script src=\"http://platform.twitter.com/widgets.js\" charset=\"utf-8\"></script>")
          fp.puts(html)
          fp.puts("</body>")
          fp.puts("</html>")
        }
      }.trap { |e|
        puts e
        puts e.backtrace
      }
    rescue => e
      puts e
      puts e.backtrace
    end
  }

  # 設定
  settings(_("HTMLとして保存")) {
    # input("保存フォルダ", :save_as_oembed_folder)
    dirselect("保存フォルダ", :save_as_oembed_folder, UserConfig[:save_as_oembed_folder])
  }
}
