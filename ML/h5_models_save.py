# Before running this script, use conda to load the correct environment.
# `conda env create -f coreml_environment.yml`
# `source activiate coreml`

from keras.applications.resnet50 import ResNet50
from keras.models import load_model, Model
from keras.layers import GlobalAveragePooling2D, Dropout, Dense

# create student model from existing resnet50 model
resnet_50_model = ResNet50(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
last = resnet_50_model.output
x = GlobalAveragePooling2D()(last)
x = Dense(512, activation='relu')(x)
x = Dropout(0.5)(x)
preds = Dense(133, activation='softmax')(x)
student_model = Model(resnet_50_model.input, preds)

# set model weights
student_model_stump = load_model('models/StudentDogModelStump.h5')
student_model.layers[-4].set_weights(student_model_stump.layers[0].get_weights())
student_model.layers[-3].set_weights(student_model_stump.layers[1].get_weights())
student_model.layers[-2].set_weights(student_model_stump.layers[2].get_weights())
student_model.layers[-1].set_weights(student_model_stump.layers[3].get_weights())

# compile and save student model
student_model.compile(optimizer='rmsprop', loss='categorical_crossentropy', metrics=['accuracy'])
student_model.save('models/StudentDogModel.h5')
