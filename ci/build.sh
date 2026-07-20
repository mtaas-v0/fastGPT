#!/bin/bash

set -ex

echo at build.sh FC is $FC
if [ "$GITHUB_ACTIONS" = "true" ] && [[ "$(uname -s)" == *"MSYS"* || "$(uname -s)" == *"MINGW"* ]]; then
    echo "Running on a Windows runner in GitHub CI under MSYS Bash!"
    WINDOWS_RUNNER=true
    # Your Windows-specific CI code goes here
else
    echo "Not a GitHub Actions Windows MSYS environment."
    WINDOWS_RUNNER=false
fi

if [ "$WINDOWS_RUNNER" = "true" ]; then 
  
    cmake -G "Ninja"  -D CMAKE_Fortran_COMPILER=$FC .
    cmake --build .
else
  
    cmake .  -D CMAKE_Fortran_COMPILER=$FC
    make
fi


mkdir models
python create_model.py --models_dir "models" --model_size "124M"
./gpt2
ctest

if [ "$WINDOWS_RUNNER" = "true" ]; then 
  exit 0
fi

make clean
rm CMakeCache.txt
cmake -DFASTGPT_BLAS=OpenBLAS .
make
time OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 ./gpt2

rm model.gguf
curl -o model.gguf -L https://huggingface.co/certik/fastGPT/resolve/main/model_fastgpt_124M_v2.gguf
time OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 ./gpt2

rm gpt2
python pt.py
