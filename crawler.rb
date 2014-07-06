#!/usr/bin/ruby
require 'open-uri'
require 'net/http'
require 'fileutils'
require 'thread'
#require 'nokogiri'
require 'mongo'
require 'hpricot'


class Crawler
  @@interval = 2
  @@rootpath = "imgs/"

  def initialize(seeds, threadNum)
    @tasks = Queue.new
    @finished = {}
    @saved = {}
    @threadNum = threadNum
    @seeds = []
    @db = Mongo::Connection.new.db("mydb")
    @coll = @db.collection("imgserver")
    File.open(seeds, "r") {|file|
      while line = file.gets
        ss = line.split("\t")
        @seeds << [ss[0], ss[1]]
      end
    }
    @proxy = {
      :proxy_http_basic_authentication => [URI.parse('http://127.0.0.1:7777'), "", ""]
    }
    @pwd = Dir.pwd
  end

  def fetch(url, base)
    pwd = url[0..url.rindex("/")]   #with last /
    root = /http:\/\/\S+?\//.match(url).to_s
    root = root[0..root.length - 2]   #without last /
    if root == nil || root.length < 7
      return {
        "title" => "NONE",
        "links" => [],
        "imgs" => []
      }
    end
    ret = {}

    page = open(url, @proxy)
    #page = open(url)
    content = page.read#.encode("UTF-8")
    #ret["content"] = content

    #doc = Nokogiri::HTML::Document.parse(content)
    doc = Hpricot(content)
    ret["title"] = doc.at("title").inner_html    #doc.css("title").text

    retLinks = []
    links = doc.search("/html/body//a")    #doc.css("a")
    links.each {|link|
      #href = link["href"]
      href = link.attributes["href"]
      if href == nil
        next
      end
      if href.start_with?("http://") || href.start_with?("https://")
        if href.start_with?(root)
          retLinks << href
        end
      elsif  href[0] == "/"
        retLinks << root + href
      else
        retLinks << pwd + href
      end
    }
    ret["links"] = retLinks

    imgs = content.scan(/http:\/\/\S+?\.jpg/)
    retImgs = []
    imgs.each {|img|
      img = img.gsub(/\/big\//, '/pic/')
      if img.start_with?("http://")
        if img.index(base) != nil
          retImgs << img
        end
      elsif img[0] == "/"
        retImgs << root + img
      else
        retImgs << pwd + img
      end
    }
    ret["imgs"] = retImgs

    return ret
  end

  def urlFetched(url)
    return @finished[url]
  end

  def urlMarkdown(url)
    puts "add url: #{url}"
    @finished[url] = true
  end

  def picFetched(pic)
    return @saved[pic]
  end

  def picMarkdown(pic, path, title)
    res = @coll.find({"title" => title})
    if res.has_next?
      record = res.next
      id = record["_id"]
      pics = record["pics"]
      pics << path
      @coll.update({"_id" => id}, {"title" => title, "pics" => pics})
    else
      @coll.insert({"title" => title, "pics" => [path]})
    end
    @saved[pic] = true
  end

  def start(num)
    @seeds.each{|tt|
      @tasks << tt
    }

    count = 0
    threads = []
    @threadNum.times{|id|
      threads << Thread.new{
        sleep(id * 2)
        puts "thread #{id} start!"
        while !@tasks.empty?
          #puts @tasks.pop
          tt = @tasks.pop
          if urlFetched(tt[0])
            next
          end

          begin
            res = fetch(tt[0], tt[1])
            #puts res["title"]
            urlMarkdown(tt[0])

            res["links"].each {|link|
              if urlFetched(link)
                next
              end

              @tasks << [link, tt[1]]
            }

            res["imgs"].each {|img|
              img.encode!("UTF-8")
              if picFetched(img)
                next
              end

              uri = URI.parse(img)
              dd = /(.*\/)(.*)/.match(uri.path)
              #puts "img: #{img}"
              #puts img.encoding
              dirs = (@pwd + "/" + @@rootpath + uri.host + dd[1]).encode!("UTF-8")
              relativepath = (@@rootpath + uri.host + uri.path).encode!("UTF-8")
              #puts "dirs: #{dirs}"
              #puts dirs.encoding
              #puts "relative: #{relativepath}"
              #puts relativepath.encoding
              picMarkdown(img, relativepath, res["title"])
              FileUtils::mkdir_p(dirs)
              #puts "mkdir ok"
              open(img, @proxy) {|pic|
                open(@pwd + "/" + relativepath, 'wb') {|file| file << pic.read}
              }
              #open(@pwd + "/" + relativepath, 'wb') {|file| file << open(img, @proxy).read}
              #open(@pwd + "/" + relativepath, 'wb') {|file| file << open(img).read}
              puts "save #{count} pic #{img} by thread #{id}"
              sleep(@@interval)

              count += 1
            }
          rescue Exception => msg
            puts "Exception: #{msg} @ #{$1}"
            if $1 != nil
              puts $1.encoding
            end
          end

          #if count > num
          #  return
          #end
        end
      }
    }
    threads.each{|tt|
      tt.join
    }
  end

end


#puts $*.length
#$*.each{|arg| puts arg}
if $*.length != 4
  puts "Usage: crawler.rb -t <thread number> -n <picture number>"
else
  crawler = Crawler.new('seeds.txt', $*[1].to_i)
  #puts crawler.fetch('http://www.22mm.cc/mm/qingliang/PiaCPJdmdbHaHPHmJ-5.html', '.meimei22.')
  crawler.start($*[3].to_i)
end

