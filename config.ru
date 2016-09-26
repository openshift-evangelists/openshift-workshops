require 'sinatra/base'

require 'redcarpet'
require 'asciidoctor'

require 'yaml'

class WorkshopRenderer < Redcarpet::Render::HTML
  def image(link, title, alt)
    link = "/#{link}" unless link[0] == '/'
    "<img src='#{link}' title='#{title}' alt='#{alt}'>"
  end

  def link(link, title, content)
    link = '.' if link == '/'
    "<a href='#{link}' title='#{title}'>#{content}</a>"
  end
end

class Application < Sinatra::Base

  set :config, Dir.glob('labs/*.yml').map { |lab| [lab, YAML.load(File.read("#{lab}"))] }
                   .inject({}) { |labs, lab| labs[File.basename(lab[0], '.yml')] = lab[1]; labs }

  set :modules, YAML.load(File.read('config/modules.yml'))
  set :markdown, Redcarpet::Markdown.new(WorkshopRenderer, fenced_code_blocks: true, extensions: {})

  helpers do

    def list_modules
      @modules = settings.modules
      @active_modules = settings.config[@id]['modules'] || @modules.keys.clone
      @active_modules.each do |mod|
        @modules[mod]['requires'].each do |m|
          @active_modules << m unless @active_modules.include?(m)
        end if @modules[mod]['requires']
      end
    end

    def render_module(mod)
      case
        when File.exists?("modules/#{mod}.md")
          src = File.read("modules/#{mod}.md")
          [src, settings.markdown.render(src)]
        when File.exists?("modules/#{mod}.adoc")
          src = File.read("modules/#{mod}.adoc")
          attributes = ENV.clone
          settings.config[@id]['vars'].each_key do |key|
            attributes[key] = settings.config[@id]['vars'][key] unless attributes[key]
          end if settings.config[@id]['vars']
          [src, Asciidoctor.render(src, attributes: attributes)]
        else
          [nil, nil]
      end
    end

  end

  get '/' do
    if ENV['DEFAULT_LAB']
      redirect "/#{ENV['DEFAULT_LAB']}"
    else
      @labs = settings.config
      erb :index
    end
  end

  get '/:id/?' do
    @id = params[:id]
    @lab = settings.config[@id]
    list_modules
    erb :lab
  end

  get '/:id/complete/?' do
    @id = params[:id]
    @lab = settings.config[@id]
    list_modules
    @src, @content = @modules.keys.inject(['', '']) do |content, mod|
      next unless @active_modules.include?(mod)
      src, c = render_module(mod)
      content[0] << src
      content[1] << c
      content
    end
    erb :module
  end


  get '/:id/:module/?' do
    @id = params[:id]
    @module = params[:module]
    @src, @content = render_module(@module)
    erb :module
  end

end

run Application