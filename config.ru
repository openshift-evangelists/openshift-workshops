require 'sinatra/base'

require 'asciidoctor'
require 'liquid'

require 'yaml'
require 'kramdown'
require 'json'
require 'multi_markdown'
require 'multi_json'

class Application < Sinatra::Base

  helpers do

    def labs
      if !@labs || settings.development?
        @labs = Dir.glob('labs/*.yml').map do |lab|
          [lab, YAML.load(File.read("#{lab}"))]
        end.inject({}) do |labs, lab|
          labs[File.basename(lab[0], '.yml')] = lab[1]; labs
        end
      end
      @labs
    end

    def config
      if !@config || settings.development?
        @config = YAML.load(File.read('config/config.yml'))
      end
      @config
    end

    def modules
      if !@modules || settings.development?
        @modules = YAML.load(File.read('config/modules.yml'))
      end
      @modules
    end

    def list_modules
      @modules = modules
      @active_modules = (@lab && @lab['modules'] && @lab['modules']['activate']) || @modules.keys.clone
      @active_modules.each do |mod|
        @modules[mod]['requires'].each do |m|
          @active_modules << m unless @active_modules.include?(m)
        end if @modules[mod]['requires']
      end
      @active_modules
    end

    def process_template(name, revision, source)
      variables = config['vars'] || {}

      modules[name]['vars'].each_key do |key|
        variables[key] = modules[name]['vars'][key]
      end if modules[name]['vars']

      if modules[name] && modules[name]['revisions'] && modules[name]['revisions'][revision]
        modules[name]['revisions'][revision]['vars'].each_key do |key|
          variables[key] = modules[name]['revisions'][revision]['vars'][key]
        end
      end

      @lab['vars'].each_key do |key|
        variables[key] = @lab['vars'][key]
      end if @lab['vars']

      ENV.each_key do |key|
        variables[key] = ENV[key]
      end

      @lab['modules'] ||= {}
      @lab['modules']['activate'] = list_modules
      @lab['modules']['revisions'] ||= {}

      variables['modules'] = @lab['modules']['activate'].inject({}) { |c,i| c[i] = true; c }
      variables['revisions'] ||= variables['modules'].keys.inject({}) do |c, i|
        c[i] = @lab['modules']['revisions'][i] || @lab['revision']
        c
      end

      template = Liquid::Template.parse(source)
      template.render!(variables)
    end

    def render_module(mod)
      revision = case
                   when @lab['modules'] && @lab['modules']['revisions'] && @lab['modules']['revisions'][mod]
                     @lab['modules']['revisions'][mod]
                   when  @lab['revision']
                     @lab['revision']
                   else
                     nil
      end

      filename = "modules/#{mod}.adoc"
      if revision
        tmp = "modules/#{mod}_#{revision}.adoc"
        filename = tmp if File.exists?(tmp)
      end

      case
        when File.exists?(filename)
          src = File.read(filename)
          options = { attributes: { 'icons' => 'font' } }
          adoc = Asciidoctor::Document.new(process_template(mod, revision, src), options)
          [src, adoc.render]
        else
          [nil, nil]
      end
    end

    def markdown(content)
      MultiMarkdown.new(content).to_html
    end

  end

  get '/' do
    if ENV['DEFAULT_LAB']
      redirect "/#{ENV['DEFAULT_LAB']}"
    else
      @labs = labs
      erb :index
    end
  end

  post '/_custom' do
    @id = params[:id]
    @lab = YAML.load(params[:lab][:tempfile].read)
    list_modules
    mods = modules.each_key.inject([]) do |temp, id|
      next temp unless @active_modules.include?(id)
      temp << {
          id: id,
          name: settings.modules[id]['name']
      }
    end
    MultiJson.dump(mods)
  end

  get '/:id/?' do
    @id = params[:id]
    @lab = labs[@id]
    list_modules
    erb :lab
  end

  get '/:id/_complete/?' do
    @id = params[:id]
    @lab = labs[@id]
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
    @lab = labs[@id]
    @src, @content = render_module(@module)
    erb :module
  end

  post '/_custom/:module/?' do
    @id = params[:id]
    @module = params[:module]
    @lab = YAML.load(params[:lab][:tempfile].read)

    @src, @content = render_module(@module)
    @content
  end

end

run Application
