# Before running this script, use conda to load the correct environment.
# `conda env create -f ../coreml-environment.yml`
# `source activiate coreml`

import sys
import coremltools
from PIL import Image
from operator import itemgetter

coreml_model = coremltools.models.MLModel('../models/StudentDogModel.mlmodel')
text_file = open('dog_names.txt', 'r')
dog_names = text_file.read().split('\n')

def prepare_image(image_path):
    img = Image.open(image_path)
    img = img.resize((224, 224), Image.ANTIALIAS)
    return img

def student_model_predict_label_coreml(image_path):
    """ uses the student's model to predict dog breed """
    image = prepare_image(image_path)
    # return dog_names[np.argmax(coreml_model.predict({'image': image}))]
    return probs_for_breeds_coreml(coreml_model.predict({'image': image}))

def probs_for_breeds_coreml(breed_predictions):
    sorted_predictions = sorted(breed_predictions['classLabelProbs'].items(), key=itemgetter(1), reverse=True)[:5]
    for prediction in sorted_predictions:
        print prediction[0] + ': ' + str(prediction[1])

if __name__ == '__main__':
    image_path = sys.argv[1]
    print('STUDENT MODEL (CoreML):')
    print(student_model_predict_label_coreml(image_path))
