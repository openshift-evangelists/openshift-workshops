require 'sinatra/base'

require 'redcarpet'
require 'asciidoctor'
require 'liquid'

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

  set :labs, Dir.glob('labs/*.yml').map { |lab| [lab, YAML.load(File.read("#{lab}"))] }
                   .inject({}) { |labs, lab| labs[File.basename(lab[0], '.yml')] = lab[1]; labs }

  set :config, YAML.load(File.read('config/config.yml'))
  set :modules, YAML.load(File.read('config/modules.yml'))
  set :markdown, Redcarpet::Markdown.new(WorkshopRenderer, fenced_code_blocks: true, extensions: {})

  helpers do

    def list_modules
      @modules = settings.modules
      @active_modules = (settings.labs[@id]['modules'] && settings.labs[@id]['modules']['activate']) || @modules.keys.clone
      @active_modules.each do |mod|
        @modules[mod]['requires'].each do |m|
          @active_modules << m unless @active_modules.include?(m)
        end if @modules[mod]['requires']
      end
    end

    def process_template(name, source)
      variables = settings.config['vars'] || {}

      settings.modules[name]['vars'].each_key do |key|
        variables[key] = settings.modules[name]['vars'][key]
      end if settings.modules[name]['vars']

      settings.labs[@id]['vars'].each_key do |key|
        variables[key] = settings.labs[@id]['vars'][key]
      end if settings.labs[@id]['vars']

      ENV.each_key do |key|
        variables[key] = ENV[key]
      end

      template = Liquid::Template.parse(source)
      template.render!(variables)
    end

    def render_module(mod)
      cfg = settings.labs[@id]

      filename = mod
      if cfg['modules'] && cfg['modules']['revisions'] && cfg['modules']['revisions'][mod]
        filename += "_#{cfg['modules']['revisions'][mod]}"
      end

      case
        when File.exists?("modules/#{filename}.md")
          src = File.read("modules/#{filename}.md")
          [src, settings.markdown.render(process_template(mod, src))]
        when File.exists?("modules/#{filename}.adoc")
          src = File.read("modules/#{filename}.adoc")
          [src, Asciidoctor.render(process_template(mod, src))]
        else
          [nil, nil]
      end
    end

  end

  get '/' do
    if ENV['DEFAULT_LAB']
      redirect "/#{ENV['DEFAULT_LAB']}"
    else
      @labs = settings.labs
      erb :index
    end
  end

  get '/:id/?' do
    @id = params[:id]
    @lab = settings.labs[@id]
    list_modules
    erb :lab
  end

  get '/:id/complete/?' do
    @id = params[:id]
    @lab = settings.labs[@id]
    list_modules
    @src, @content = @modules.keys.inject(['', '']) do |content, mod|
      next content unless @active_modules.include?(mod)
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