# Reflection

## 1. Which part of your submission are you least confident about, and why?

The part I'm least confident about is the UI design. I aimed for a Netflix-inspired interface while keeping the implementation simple and maintainable within the available time. Although the functionality is complete, I believe the visual polish, animations, and spacing could be improved further to create a more premium user experience.

---

## 2. Describe a moment during this project (or any past project) where you got completely stuck. What did you do, step by step?

One example was while building a SwiftUI application using SwiftData. I ran into a problem where the data flow between the model and the UI wasn't behaving as expected, and I wasn't sure whether the issue came from SwiftData, my architecture, or SwiftUI itself.

The steps I took were:

1. Reproduced the issue consistently with the smallest possible example.
2. Read Apple's documentation to verify how the API was intended to work.
3. Checked developer discussions and community examples to compare approaches.
4. Added logging and breakpoints to understand where the state stopped updating.
5. Refactored the code into smaller components to isolate the problem.
6. Once I found the root cause, I cleaned up the implementation instead of only applying a quick fix.

That experience reinforced the importance of isolating problems before trying multiple solutions.

---

## 3. Imagine: it's Thursday, your task is due Friday, and you realize you misunderstood the requirement, half your work is wrong. What are you doing now?

First, I would stop adding new features and carefully reread the requirements to understand exactly what needs to change.

Next, I would identify which parts can still be reused and prioritize the required functionality over optional improvements. If necessary, I would simplify the implementation to ensure the project meets all core requirements before the deadline.

If I were working with a team or mentor, I would communicate the situation early rather than waiting until the deadline. I'd rather submit a simpler solution that fully satisfies the requirements than a more complex one that solves the wrong problem.

---

## 4. Your mentor asks you to change an approach you believe is worse. What do you do?

I would first ask about the reasoning behind the suggestion. There may be project constraints, business requirements, or team conventions that I'm unaware of.

If I still believe another approach would be better, I would respectfully explain the trade-offs and provide technical reasons rather than opinions. Ultimately, if the final decision is to follow the mentor's approach, I would implement it while making sure the code remains clean and maintainable. I believe consistency within a team is often more valuable than every developer using their preferred solution.

---

## 5. What's something technical you taught yourself recently outside of class/work, and how did you learn it?

Recently, I spent time learning SwiftUI architecture and modern iOS development patterns, including MVVM, SwiftData, and Swift Concurrency.

I learned by building personal projects rather than only reading documentation. Whenever I encountered a problem, I would first consult Apple's documentation, then compare different community approaches, experiment with small prototypes, and finally integrate the solution into a larger application. Building real applications helped me understand not only how the APIs work, but also why certain architectural decisions make the code easier to maintain and test.