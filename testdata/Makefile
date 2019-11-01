gentestdata:
	dub run dubproxy -- -m true -n allcodedlangpackages.json
	dub run dubproxy -- -a allcodedlangpackages.json -u true --verbose --genAllTags true \
		--overrideTree yes -o ../testpackages -f ../testpackages \
		--proxyFile allcodedlangpackages.json
