# Crossover Content: Machine Learning and iOS

The purpose of this repository is track collaborative, crossover content development between the Machine Learning and iOS content teams. Here you will find an example iOS application that utilizes ResNet50 to calculate the probabilities that an image or video frame contains an object described by its (1,000) categories. The app also utilizes a student model which, provided an image of a dog, calculates the probability that the dog contained within the image is of a certain breed.

## Structure

- iOS/
	- Contains Xcode project for iOS application
- ML/
	- Keras Models
		- `ML/ResNet50_for_iOS.h5`
			- LABELS: [found here](https://gist.github.com/yrevar/942d3a0ac09ec9e5eb3a) - dogs correspond to 151-268, inclusive
		- `ML/student_model_for_iOS.h5`
			- LABELS: `ML/dog_names.txt` - all are dogs
	- Jupyter Notebook
		- `ML/some_notes.ipynb` = sample labels for student model (top label) and ResNet-50 model (top 5 labels w/ probabilities) on the images located in the `ML/images` folder
