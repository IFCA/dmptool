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
  when "sup"
    {:text => n.text,
      :styles => [:superscript]}
  when "sub"
    {:text => n.text,
      :styles => [:subscript]}
  when "text"
    {:text => n.text}
  else
    raise Exception.new("Unexpected tag: #{n.name}.")
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
          print_responses(pdf, child, "#{heading}.#{i+1}")
        end
      end
    else
      html = Nokogiri::HTML(response_value_s(Response.where(:requirement=>requirement, :plan=>@plan).first))
      pdf.font("Helvetica", :style=>:normal)
      pdf.pad(10) do
        pdf.indent(12) do
          render_html(pdf, html)
        end
      end
    end
  end
end

pdf = Prawn::Document.new(:bottom_margin=>72) do |pdf|
  pdf.font_size(20)
  pdf.text(@plan.name)

  pdf.move_down 10
  pdf.stroke_horizontal_rule
  pdf.move_down 10

  @plan.requirements_template.requirements.order(:position).roots.each_with_index do |req, i|
    print_responses(pdf, req, (i + 1).to_s)
  end

  # Generate footer
  pdf.repeat :all do
    pdf.canvas do
      pdf.bounding_box([pdf.bounds.left, pdf.bounds.bottom + 60],
                       :width  => pdf.bounds.absolute_left + pdf.bounds.absolute_right,
                       :height => 60) do
        pdf.stroke_horizontal_rule
        pdf.move_down(5)
        pdf.text("Generated by the DMPTool on #{Time.now.to_formatted_s(:long)}", :size => 12, :align=>:center)
      end
    end  
  end
end
pdf.render
