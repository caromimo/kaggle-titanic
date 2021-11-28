# DOWNLOAD DATA FROM KAGGLE

.PHONY: download
download:
		kaggle competitions download -c titanic -p data/raw/

.PHONY: unzip
unzip:
		unzip data/raw/titanic.zip -d data/raw/
		
.PHONY: clean
clean:
		rm data/raw/titanic.zip		
		
.PHONY: raw
raw: download unzip clean

.PHONY: data
data:
		Rscript scripts/cleaning.R	
		
.PHONY: model
model:
		Rscript scripts/modeling.R	