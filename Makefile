deploy:
	git push origin master
	hexo clean
	hexo generate
	hexo deploy
