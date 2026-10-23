# ===========================================================
# AeroSense TN — train_model.R (Wrapper for train.R)
# Ensures backward compatibility with existing scripts
# ===========================================================

train_script <- if (file.exists("train.R")) "train.R" else if (file.exists("backend/train.R")) "backend/train.R" else "../backend/train.R"
source(train_script)

if (sys.nframe() == 0) {
  train_aqi_model()
}
