# install.packages("e1071")

# Load required library
library(e1071)

# Load dataset
library(datasets)
data(iris)

# Convert species to binary class: setosa vs. others
iris$Species <- ifelse(iris$Species == "setosa", "setosa", "others")

# Split dataset into training and testing sets
set.seed(135)
train_index <- sample(nrow(iris), 100)
train_data <- iris[train_index, ]
test_data <- iris[-train_index, ]

# Train Naive Bayes classifier
model <- naiveBayes(Species ~ Sepal.Length + Sepal.Width + Petal.Length + Petal.Width, data = train_data)

# Predict
predictions <- predict(model, test_data)

# Confusion matrix
table(predictions, test_data$Species)

# Confusion matrix
conf_matrix <- table(predictions, test_data$Species)
print(conf_matrix)

# Compute accuracy
accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)
print(paste("Accuracy:", round(accuracy * 100, 2), "%"))
