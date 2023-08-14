all
# our changelog does this, by design
# MD013 - Line length
exclude_rule 'MD013'
# MD041 First line in file should be a top level header
exclude_rule 'MD041'
# default in next version, remove then
#rule 'MD007', :indent => 3
exclude_rule 'MD046'
exclude_rule 'MD002'

rule 'MD003', :style => :atx