# for saving resnet-50 model
from keras.applications.resnet50 import ResNet50
model = ResNet50(weights='imagenet', input_shape=(224, 224, 3))
model.compile(optimizer='rmsprop', loss='categorical_crossentropy', metrics=['accuracy'])
model.save('final_models/ResNet50_for_iOS.h5')

# for saving student model
from keras.applications.resnet50 import ResNet50
from keras.models import load_model, Model
from keras.layers import GlobalAveragePooling2D, Dropout, Dense

resnet_50_model = ResNet50(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
last = resnet_50_model.output
x = GlobalAveragePooling2D()(last)
x = Dense(512, activation='relu')(x)
x = Dropout(0.5)(x)
preds = Dense(133, activation='softmax')(x)

student_model = Model(resnet_50_model.input, preds)

student_model_stump = load_model('student_model_stump_keras1.h5')
student_model.layers[-4].set_weights(student_model_stump.layers[0].get_weights())
student_model.layers[-3].set_weights(student_model_stump.layers[1].get_weights())
student_model.layers[-2].set_weights(student_model_stump.layers[2].get_weights())
student_model.layers[-1].set_weights(student_model_stump.layers[3].get_weights())

student_model.compile(optimizer='rmsprop', loss='categorical_crossentropy', metrics=['accuracy'])
student_model.save('final_models/student_model_for_iOS.h5')