# -*- mode: ruby -*-
require 'nokogiri'

def mk_formatted_text(n)
  case n.name
  when "b", "strong"
    {:text => n.text,
      :styles => [:bold]}
  when "i", "em"
    {:text => n.text,
      :styles => [:italic]}
  when "u"
    {:text => n.text,
      :styles => [:underline]}
  when "s"
    {:text => n.text,
      :styles => [:strikethrough]}
  when "sup"
    {:text => n.text,
      :styles => [:superscript]}
  when "sub"
    {:text => n.text,
      :styles => [:subscript]}
  when "text"
    {:text => n.text}
  when "br"
    {:text => "\n" }
  when "a"
    {:text => "#{n.text} (#{n['href']})",
      :styles => [:underline]}
  else
    #raise Exception.new("Unexpected tag: #{n.name}.")
    {:text => n.text }
  end
end

def mk_formatted_texts(n)
  return n.map {|c| mk_formatted_text(c)}
end

def render_html(pdf, n, state={})
  case n.name
  when "document", "html", "body"
    n.children.each do |c|
      render_html(pdf, c)
    end
  when "p"
    pdf.formatted_text(mk_formatted_texts(n.children))
  when "ul"
    pdf.indent(10) do
      n.children.each do |li|
        render_html(pdf, li, {:list_mode=>:ul})
      end
    end
  when "ol"
    pdf.indent(10) do
      # keep this here so that render_html can modify it
      state = {:list_mode=>:ol, :index=>1}
      n.children.each do |li|
        render_html(pdf, li, state)
      end
    end
  when "li"
    if state[:list_mode] == :ul
      pdf.formatted_text([{:text=>"\u2022 "}] + mk_formatted_texts(n.children))
    else # :ol
      pdf.formatted_text([{:text=>"#{state[:index]}. "}] + mk_formatted_texts(n.children))
      state[:index] = state[:index] + 1
    end
  when "hr"
    pdf.stroke_horizontal_rule
  else
    if !n.text.blank? then
      pdf.formatted_text([mk_formatted_text(n)])
    end
  end
end

def print_responses(pdf, requirement, heading)
  pdf.pad(12) do
    pdf.font_size(14)
    pdf.font("Helvetica", :style=>:normal)
    pdf.formatted_text([{:text=> heading, :styles=>[:normal]},
                        {:text=> " #{requirement.text_brief.to_s}", :styles=>[:bold]}])
    if requirement.children.size > 0 then
      pdf.indent(12) do
        requirement.children.order(:position).each_with_index do |child, i|
          # print_responses(pdf, child, "#{heading}.#{i+1}")
          print_responses(pdf, child, "")
        end
      end
    else
      html = Nokogiri::HTML(requirement.response_html(@plan))
      pdf.font("Helvetica", :style=>:normal)
      pdf.pad(10) do
        pdf.indent(12) do
          render_html(pdf, html)
        end
      end
    end
  end
end


pdf = Prawn::Document.new(:bottom_margin=>50, :top_margin=>60, :left_margin=>50) do |pdf|
  @cover = false
  if @plan.visibility == :public

    @cover = true

    lifewatch = "#{Rails.root}/app/assets/images/lifewatch.png"
    pdf.image(lifewatch, :at => [430,730],:scale => 0.4)

    pdf.stroke do
      pdf.fill_color "808080"
      pdf.stroke_color "808080"
      pdf.rectangle [0, 688], 518, 3
      pdf.fill
    end


    pdf.fill_color "000000"
    pdf.stroke_color "000000"

    pdf.move_cursor_to 670

    pdf.font_size(20)

    pdf.span(350, :position => :center) do
       pdf.text(@plan.name, :style => :bold, :align => :center, :position => :center)
    end
    
    pdf.move_down 14

    pdf.font_size(14)

    pdf.span(400, :position => :center) do
      pdf.text("A Data management plan created using the LifeWatch DMPTool", :style => :italic)
    end


    @coowners = @plan.coowners

    @coowners.length>0 ? @separator=", " : @separator=""  

    pdf.move_down 35
    pdf.text("Creator(s): " + @plan.owner.full_name + @separator + @coowners.map { |coowner| coowner.full_name.to_s }.join(", ") ) 
    pdf.move_down 14
    pdf.text("Affiliation: " + @plan.owner.institution.name)
    
    pdf.move_down 14
    
    pdf.text("Last modified: " + @plan.updated_at.strftime("%B %d, %Y"))
    
    pdf.move_down 14
  
    pdf.text("Copyright information: The above plan creator(s) have agreed that others may use ")
    pdf.text("as much of the text of this plan as they would like in their own plans, and customize ")
    pdf.text("it as necessary. You do not need to credit the creators as the source of the ")
    pdf.text("language used, but using any of their plan's text does not imply that the creator(s) ")
    pdf.text("endorse, or have any relationship to, your project or proposal.")

    pdf.stroke do
      pdf.fill_color "808080"
      pdf.stroke_color "808080"
      pdf.rectangle [0, 18], 518, 3
      pdf.fill
    end

    pdf.fill_color "000000"
    pdf.stroke_color "000000"

    pdf.start_new_page

  end
lifewatch = "#{Rails.root}/app/assets/images/lifewatch.png"
  pdf.image(lifewatch, :at => [430,710],:scale => 0.4)

  pdf.font_size(20)
  pdf.text(@plan.name)

  pdf.move_down 10
  pdf.stroke_horizontal_rule
  pdf.move_down 10

  @plan.requirements_template.requirements.order(:position).roots.each_with_index do |req, i|
    # print_responses(pdf, req, (i + 1).to_s) #with ordering
    print_responses(pdf, req, "") #without ordering
  end

  # Generate footer for every page except cover if cover is present
  if @cover == true
    pdf.repeat(lambda { |pg| pg != 1 }) do
      pdf.canvas do
        pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 40],
                         :width  => pdf.bounds.absolute_left + pdf.bounds.absolute_right,
                         :height => 40) do
          pdf.stroke_horizontal_rule
          pdf.move_down(5)
          pdf.text("Created using the Lifewatch DMPTool. Last modified #{@plan.updated_at.strftime("%B %d, %Y")}", :size => 12, :align=>:center)
        end
      end  
    end
  else
    pdf.repeat :all do
      pdf.canvas do
        pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 40],
                         :width  => pdf.bounds.absolute_left + pdf.bounds.absolute_right,
                         :height => 40) do
          pdf.stroke_horizontal_rule
          pdf.move_down(5)
          pdf.text("Created using the Lifewatch DMPTool. Last modified #{@plan.updated_at.strftime("%B %d, %Y")}", :size => 12, :align=>:center)
        end
      end  
    end
  end
end

pdf.render









