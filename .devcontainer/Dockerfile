FROM julia:1.7

RUN apt-get update && apt-get install -y xz-utils bzip2 sudo git unzip vim

RUN julia -e 'using Pkg; Pkg.add("Revise")'
