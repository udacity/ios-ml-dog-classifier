import sys
import numpy as np
from keras.models import load_model
from keras.preprocessing import image
from keras.applications.resnet50 import decode_predictions, preprocess_input

test_resnet_model = load_model('final_models/ResNet50_for_iOS.h5')
test_student_model = load_model('final_models/student_model_for_iOS.h5')
text_file = open('dog_names.txt', 'r')
dog_names = text_file.read().split('\n')

def path_to_tensor(img_path):
    """ preprocessing - resize the image, subtract mean pixel, change dimensionality of input """
    img = image.load_img(img_path, target_size=(224, 224))
    x = image.img_to_array(img)
    x = np.expand_dims(x, axis=0)
    return preprocess_input(x)

def ResNet50_model_predict_label(proc_tensor):
    """ uses the ResNet-50 model from the documentation to predict label """
    return decode_predictions(test_resnet_model.predict(proc_tensor), top=5)

def student_model_predict_label(proc_tensor):
    """ uses the student's model to predict dog breed """
    return dog_names[np.argmax(test_student_model.predict(proc_tensor))]

if __name__ == '__main__':
    img_path = sys.argv[1]
    proc_tensor = path_to_tensor(img_path)
    print('RESNET:')
    print(ResNet50_model_predict_label(proc_tensor))
    print('STUDENT:')
    print(student_model_predict_label(proc_tensor))