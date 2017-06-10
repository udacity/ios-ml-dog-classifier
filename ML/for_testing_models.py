from keras.models import load_model

test_resnet_model = model.load('final_models/ResNet50_for_iOS.h5')
test_student_model = model.load('final_models/student_model_for_iOS.h5')

