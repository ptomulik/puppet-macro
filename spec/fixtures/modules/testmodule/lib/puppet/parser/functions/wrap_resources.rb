# mymodule/lib/puppet/parser/function/wrap_resources
def remove_undefs_from_params(params)
  Hash[params.select{|param,value| value and not value.empty? and not value.equal?(:undef)}]
end
def remove_undefs(resources)
  Hash[resources.map{ |title,params| [title, remove_undefs_from_params(params)]}]
end
Puppet::Parser::Functions.newfunction 'wrap_resources' do |args|
  type = args[0]
  function_create_resources([type, remove_undefs(args[1])])
end
