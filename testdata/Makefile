gentestdata:
	dub run dubproxy -m true -n allcodedlangpackages.json
	dub run dubproxy -i allcodedlangpackages.json -a true --verbose
	dub run dubproxy --verbose --genAllTags true \
		--overrideTree yes --packagesFolder ../testpackages --gitFolder ../testpackages \
		--proxyFile allcodedlangpackages.json
