# Social Media Polarisation Model

This repository hosts the 'Social Media Polarisation Model', an extension of the model discussed in Keijzer, Marijn, Mäs, Michael, and Flache, Andreas (2024) "Polarization on Social Media: Micro-Level Evidence and Macro-Level Implications," Journal of Artificial Societies and Social Simulation 27 (1) 7. Our model incorporates extra elements to investigate intricate interaction patterns and their consequences on social polarisation.

## Model Overview
The model simulates interactions among agents to explore how social media can influence opinion dynamics and polarisation. We augmented the foundational model by Keijzer et al (2024). to include features such as multiple group memberships, online/offline status, agent movement, and ageing processes, among others. These additions aim to provide deeper insights into the mechanisms driving opinion shifts and polarisation in virtual and physical social spaces.

## Features Comparison
For a detailed comparison between Keijzer et al (2024)'s foundational model and our augmented model, refer to the table below:

![Comparison of Features](https://github.com/t3rryhuang/Social-Media-Polarisation-Model/blob/main/python%20visualisations/comparison.png?raw=true)

## Getting Started
You can run the model directly in your browser by clicking [here](https://t3rryhuang.github.io/Social-Media-Polarisation-Model/).

### Local Setup
1. Clone the repository.
2. Open the `.nlogo` file located in the root directory with NetLogo.
3. Click the 'setup' and 'go' buttons located in the bottom right corner of the interface to initiate and observe the model dynamics.

### Interaction Dynamics
- **Online interactions** occur based on opinion similarity, determined by the bubble-size parameter/slider, allowing you to explore how information bubbles affect opinion polarisation.
- **Offline interactions** are determined by physical proximity, reflecting the influence of real-world social structures on opinion shifts.

## Research Questions
Our project addresses the following questions:
- RQ1: Is there a threshold in bubble size that transitions the system from a state of various viewpoints to one of significant polarisation, especially while sustaining a fluctuating yet stable population size?
- RQ2: How does altering the proportion of online agents affect the overall opinion dynamics of the system?
- RQ3: How does the frequency of offline interactions compared to online interactions influence the stability and variability of opinion states?

## Team
- **Terry Huang**: NetLogo implementation and co-designed experiments.
- **Blythe Wray**: Implementation documentation and preliminary design.
- **Gro Gisleberg**: Social theory research, model finetuning and designed experiments.
- **Leo Kravtchin**: Assisted in developing and concluding from polarisation metric graphs.

## Further Reading
Access our full paper [here](https://github.com/t3rryhuang/Social-Media-Polarisation-Model/blob/main/report.pdf) for a detailed discussion of our model's inspiration, implementation and findings.

## Our Model Interface
![Model Screenshot](https://github.com/t3rryhuang/Social-Media-Polarisation-Model/blob/main/model-screenshot.png?raw=true)

## Citation
If you use this model or the code from this repository, please cite:
> Keijzer, M., Mäs, M., & Flache, A. (2024). Polarization on Social Media: Micro-Level Evidence and Macro-Level Implications. Journal of Artificial Societies and Social Simulation, 27(1), 7. doi: 10.18564/jasss.5298

<sub><strong>Personal Reflection</strong><br>
While working on this project, I often reflected on themes of power and influence, which are echoed in a quote that resonated with me deeply: "I'm fairly certain he knew how I would feel about it, though, and let me just say that the definition of the toxic male privilege in our industry is people saying, 'But he's always been nice to me!' when I'm raising valid concerns about artists and their right to own their music. Of course he's nice to you. If you're in this room, you have something he needs." - Taylor Swift. Reflecting on this, I realised how similar dynamics of influence and control are, not just in the music industry but also across social media platforms and daily life, which is a central theme of this project.</sub>
