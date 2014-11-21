current_dir =  File.dirname(__FILE__)
chef_repo_path File.join(current_dir)
cookbook_path [ File.join(current_dir, '..', 'cookbooks'),
                File.join(current_dir, '..', 'berks-cookbooks') ]
cache_path File.join(current_dir, 'local-mode-cache')
