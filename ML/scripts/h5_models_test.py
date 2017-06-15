# Before running this script, use conda to load the correct environment.
# `conda env create -f ../coreml-environment.yml`
# `source activiate coreml`

import sys
import numpy as np
from keras.models import load_model
from keras.preprocessing import image
from keras.applications.resnet50 import decode_predictions, preprocess_input
from operator import itemgetter

test_student_model = load_model('../models/StudentDogModel.h5')
text_file = open('dog_names.txt', 'r')
dog_names = text_file.read().split('\n')

def path_to_tensor(img_path):
    """ preprocessing - resize the image, subtract mean pixel, change dimensionality of input """
    img = image.load_img(img_path, target_size=(224, 224))
    x = image.img_to_array(img)
    x = np.expand_dims(x, axis=0)
    return preprocess_input(x)

def student_model_predict_label_h5(img_path):
    """ uses the student's model to predict dog breed """
    #return dog_names[np.argmax(test_student_model.predict(proc_tensor))]
    proc_tensor = path_to_tensor(img_path)
    return probs_for_breeds_h5(test_student_model.predict(proc_tensor))

def probs_for_breeds_h5(breed_predictions):
    """ breed_prediction is a nparray """
    predictions = []
    for (x), value in np.ndenumerate(breed_predictions[0]):
        predictions.append([x[0], str(dog_names[x[0]]), value])
    sorted_predictions = sorted(predictions, key=itemgetter(2), reverse=True)
    for prediction in sorted_predictions[:5]:
        print dog_names[prediction[0]] + ': ' + str(prediction[2])

if __name__ == '__main__':
    img_path = sys.argv[1]
    print('STUDENT MODEL:')
    print(student_model_predict_label(img_path))
