# Need this to get picked up by autotest?
$:.push(File.join(File.dirname(__FILE__), %w[.. .. rspec]))  
   
Autotest.add_discovery do  
  "rspec" 
end