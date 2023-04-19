# Portions of this class were inspired by the XML::Util::XmlCanonicalizer class written by Roland Schmitt
 
module InformationCard
  include REXML
  
  class XmlCanonicalizer
    def initialize
      @canonicalized_xml = ''
    end
        
    def canonicalize(element)
      document = REXML::Document.new(element.to_s)
    
      #TODO: Do we need this check?
      if element.instance_of?(REXML::Element)
        namespace = element.namespace(element.prefix)
        if not namespace.empty?
          if not element.prefix.empty?
            document.root.add_namespace(element.prefix, namespace)
          else
            document.root.add_namespace(namespace)
          end 
        end
      end
      
      document.each_child{ |node| write_node(node) } 
                 
      @canonicalized_xml.strip
    end

    private  
      
    def write_node(node)
      case node.node_type
        when :text
          write_text(node)
        when :element
          write_element(node)
      end
    end
    
    def write_text(node)
      if node.value.strip.empty?
        @canonicalized_xml << node.value
      else
        @canonicalized_xml << normalize_whitespace(node.value) 
      end
    end
    
    def write_element(node)
      @canonicalized_xml << "<#{node.expanded_name}"
      write_namespaces(node)
      write_attributes(node)
      @canonicalized_xml << ">"
      node.each_child{ |child| write_node(child) }
      @canonicalized_xml << "</#{node.expanded_name}>"
    end
    
    def write_namespaces(node)
      @processed_prefixes ||= []

      prefixes = ["xmlns"] + node.prefixes.uniq

      prefixes.sort!.each do |prefix|
        namespace = node.namespace(prefix)
        
        unless prefix.empty? or (prefix == 'xmlns' and namespace.empty?) or @processed_prefixes.include?(prefix)
    		  @processed_prefixes << prefix
        
          @canonicalized_xml << " "
          @canonicalized_xml << "xmlns:" if not prefix == 'xmlns'
          @canonicalized_xml << normalize_whitespace("#{prefix}=\"#{namespace}\"")
        end
      end    
    end
    
    def write_attributes(node)
      attributes = []
      
      node.attributes.sort.each do |key, attribute|
        attributes << attribute if not attribute.prefix =~ /^xmlns/
      end
      
      attributes.each do |attribute|
        unless attribute.nil? or attribute.name == "xmlns"
          @canonicalized_xml << " #{attribute.name}=\"#{normalize_whitespace(attribute.to_s)}\""
        end
      end
    end

    def normalize_whitespace(input)      
      input.gsub(/\s+/, ' ').strip
    end
  end
end