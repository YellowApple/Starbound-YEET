SB_PACKER	= ../../linux/asset_packer
STEAMCMD	= steamcmd +login $(STEAMCMD_USER)
OUT		= ./out

$(OUT)/pkg/contents.pak: clean
	mkdir -p $(OUT)/pkg
	mkdir -p $(OUT)/src
	cp -rv interface $(OUT)/src/interface
	cp -rv items $(OUT)/src/items
	cp -rv scripts $(OUT)/src/scripts
	cp -rv stagehands $(OUT)/src/stagehands
	cp _metadata $(OUT)/src/_metadata
	cp preview.jpg $(OUT)/preview.jpg
	$(SB_PACKER) $(OUT)/src $(OUT)/pkg/YEET.pak

upload: $(OUT)/pkg/contents.pak
	mkdir -p $(OUT)/workshop
	cp $(OUT)/pkg/YEET.pak $(OUT)/workshop/contents.pak
	sed 's,{{PWD}},$(PWD),g' <metadata.vdf.template >metadata.vdf
	$(STEAMCMD) +workshop_build_item $(PWD)/metadata.vdf +quit

.PHONY: clean
clean:
	rm -rf $(OUT)
	rm -f metadata.vdf
