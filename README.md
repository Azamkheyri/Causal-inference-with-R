# 📊 Causal Inference with R

This repository collects **notes, summaries, and R code** for learning **causal inference**, with a focus on implementation in R.  
It combines academic lectures (MIT 6.S897) and applied tutorials (Malcolm Barrett’s *Causal Inference in R: The Whole Game*).

---

## 🎯 Goals

- Provide **clean R examples** of causal inference methods  
- Summarize **key theoretical lectures** (MIT 6.S897 Machine Learning for Healthcare)  
- Reproduce and annotate the **Whole Game workflow in R**  
- Share tools for **propensity score modeling, inverse probability weighting (IPW), overlap diagnostics, covariate balance checks, ATE estimation, and sensitivity analysis**

---

## 📺 Videos & Summaries

### 🎓 MIT 6.S897 Machine Learning for Healthcare, Spring 2019  
Instructor: *David Sontag*  

- **Lecture 14: Causal Inference, Part 1**  
  [Watch here](https://www.youtube.com/watch?v=gRkUhg9Wb-I)  
  - Introduces causal inference concepts: covariates (X), interventions (T), and outcomes (Y).  
  - Defines **potential outcomes**, **CATE** (Conditional Average Treatment Effect), and **ATE** (Average Treatment Effect).  
  - Discusses challenges of observational vs. randomized controlled trial (RCT) data.  
  - Explains Simpson’s Paradox and the SUTVA assumption.  
  - Methods covered:  
    - **Covariate adjustment** (machine learning models, matching)  
    - **Propensity score weighting** (re-weighting observational data to mimic RCTs).  
  - Key assumptions: ignorability (no hidden confounding) and overlap (common support).  

- **Lecture 15: Causal Inference, Part 2**  
  [Watch here](https://www.youtube.com/watch?v=g5v-NvNoJQQ)  
  - Builds on Part 1, focusing on simplified causal graph settings.  
  - Uses examples from **COVID-19** (case fatality rates in Italy vs. China).  
  - Explains differences between **machine learning vs. statistics** philosophies in causal inference.  
  - Introduces **matching** as a form of covariate adjustment.  
  - Details **propensity score methods** as a way to mimic RCTs.  
  - Reinforces importance of overlap and no hidden confounding.  

---

### 💻 Tutorial: Causal Inference in R — *Malcolm Barrett*  
[Watch here](https://www.youtube.com/watch?v=FasUOajUG64)  
[Book project: Causal Inference in R](https://www.r-causal.org/)  

- Introduces a systematic **workflow for causal inference in R**.  
- Steps:  
  1. Define a clear causal question  
  2. Draw a **DAG** (Directed Acyclic Graph) to clarify assumptions  
  3. Fit an **inverse probability weighted (IPW)** model  
  4. Create a pseudo-population where treatment & control are balanced  
  5. Estimate the causal effect  
  6. Run diagnostics & sensitivity analysis  
- Connects to the ongoing book project *Causal Inference in R*.  


---

## 🛠️ Methods Implemented in R

- Logistic regression for **propensity score estimation**  
- Inverse probability weighting (**IPW**)  
- Overlap diagnostics (**mirror histograms**)  
- Covariate balance checks (**Love plots, standardized mean differences**)  
- Weighted regression for **ATE estimation**  
- Bootstrap for uncertainty quantification  
- Sensitivity analysis with **tipr**  

---

## 🚀 Why This Repo?

I created this repo as part of my learning journey in **causal inference**.  
It combines:
- **Theory** from MIT lectures  
- **Practical implementation** in R from tutorials  

Hopefully, it will serve as a helpful starting point for others learning causal inference too!  

---

## 📖 References

- MIT OpenCourseWare: [Machine Learning for Healthcare, Spring 2019](https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-s897-machine-learning-for-healthcare-spring-2019/)  
- Malcolm Barrett — *Causal Inference in R: The Whole Game* ([YouTube](https://www.youtube.com/watch?v=FasUOajUG64), [Book project](https://www.r-causal.org/))  
- Hernán, M. & Robins, J. — *Causal Inference: What If* (free online textbook)  

---
