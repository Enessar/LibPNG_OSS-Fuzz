git clone git@github.com:google/oss-fuzz.git && cd oss-fuzz

sudo sed -i 's|git clone --depth 1 https://github.com/pnggroup/libpng.git|git clone --branch v1.6.48 --depth 1 https://github.com/pnggroup/libpng.git|' projects/libpng/Dockerfile

sudo python3 infra/helper.py build_image libpng
sudo python3 infra/helper.py build_fuzzers libpng

sudo mkdir build/out/w_corpus
sudo timeout 4h python3 infra/helper.py run_fuzzer libpng libpng_read_fuzzer --corpus-dir build/out/w_corpus
