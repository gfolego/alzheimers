# Alzheimer's Disease Detection through Whole-Brain 3D-CNN MRI

This is the source code used in the paper
"Alzheimer's Disease Detection through
Whole-Brain 3D-CNN MRI", which has been
published on Frontiers in Bioengineering
and Biotechnology.

The paper is available at Frontiers:
[https://dx.doi.org/10.3389/fbioe.2020.534592](https://dx.doi.org/10.3389/fbioe.2020.534592)

The model is available at figshare:
[https://dx.doi.org/10.6084/m9.figshare.11908536](https://dx.doi.org/10.6084/m9.figshare.11908536)

Corresponding author:
Guilherme Folego ([gfolego@gmail.com](mailto:gfolego@gmail.com))


If you find this work useful in your research, please cite the paper!  :-)

---

## Quick Guide

This has been tested with Docker version 19.03.6,
and docker-compose version 1.17.1, on Ubuntu 18.04.5.

The first step is to build the necessary docker images.
This process should take about 12 minutes, depending
on your internet connection and hardware used.

```bash
$ docker-compose build --pull
```


The algorithm works in two stages.
The first stage is to extract and normalize the brain
from the input image.
This should take a few minutes, varying according
to the input image and hardware used.

```bash
$ docker-compose run --rm adnet-brain <input_path>.nii.gz <output_path>.nii.gz
```


The second stage is to process the brain through the CNN.
This should take less than one minute.
The output file contains probabilities for CN, MCI, and AD.

```bash
$ docker-compose run --rm adnet-cnn <input_path>.nii.gz <output_path>.txt
```

### Notes

Please note that ANTs might present
some reproducibility issues.
For more details, please check
[https://github.com/ANTsX/ANTs/wiki/antsRegistration-reproducibility-issues](https://github.com/ANTsX/ANTs/wiki/antsRegistration-reproducibility-issues).

If you need any additional information
or source code, please feel free to contact us!

