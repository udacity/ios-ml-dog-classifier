# Before running this script, use conda to load the correct environment.
# `conda env create -f ../coreml-environment.yml`
# `source activiate coreml`

import coremltools

# CREDIT: https://github.com/hollance/MobileNet-CoreML/blob/master/Convert/coreml.py

# NOTE: It appears that coremltools applies the scale before subtracting
# means for normalization. So, we have to scale the mean RGB by this factor too.
rgb = [-123.68, -116.779, -103.939]
scale = 1.0

coreml_model = coremltools.converters.keras.convert(
    '../models/StudentDogModel.h5',
    input_names='image',
    image_input_names='image',
    output_names = ['classLabelProbs', 'classLabel'],
    is_bgr=True, image_scale=scale,
    red_bias=rgb[0]*scale, green_bias=rgb[1]*scale, blue_bias=rgb[2]*scale,
    class_labels='dog_names.txt')

coreml_model.author = 'James Requa'
coreml_model.license = 'More information available at https://github.com/jamesrequa/Dog-Breed-Classifier.'
coreml_model.short_description = 'A convolutional neural network that predicts canine breed from an image of a dog. Probabilities are computed for 133 different dog breeds.'

coreml_model.input_description['image'] = 'Input image to be classified.'
coreml_model.output_description['classLabelProbs'] = 'Probability of image belonging to class (breed).'
coreml_model.output_description['classLabel'] = 'Image classes (breeds).'

coreml_model.save('../models/StudentDogModel.mlmodel')
