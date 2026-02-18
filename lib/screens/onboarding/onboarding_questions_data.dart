import '../../models/onboarding_question.dart';

const List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    id: 'ayuuto_experience',
    title: 'Have you been part of\nan Ayuuto before?',
    subtitle: 'This helps us tailor the experience for you.',
    options: [
      'Yes, I run one',
      'Yes, as a member',
      'I know how it works',
      'First time — show me!',
    ],
  ),
  OnboardingQuestion(
    id: 'your_role',
    title: 'What will you mainly\nuse this app for?',
    subtitle: 'You can always do both — just pick your main one.',
    options: [
      'Organise my own circle',
      'Join someone else\'s circle',
      'Both — organise & join',
    ],
  ),
  OnboardingQuestion(
    id: 'circle_size',
    title: 'How many people are\nin your circle?',
    subtitle: 'A rough idea is fine — you can always add more later.',
    options: [
      '3–5 people',
      '6–10 people',
      '10+ people',
      'Not sure yet',
    ],
  ),
  OnboardingQuestion(
    id: 'biggest_headache',
    title: 'What\'s the hardest part\nof managing Ayuuto?',
    subtitle: 'Pick the ones that annoy you the most.',
    options: [
      'Tracking who paid',
      'Chasing late payments',
      'Keeping it fair & organised',
      'Managing it over WhatsApp',
    ],
    isMultiSelect: true,
  ),
  OnboardingQuestion(
    id: 'ready',
    title: 'You\'re all set!\nLet\'s simplify your Ayuuto',
    subtitle: 'No more spreadsheets, no more guesswork.',
    options: [
      'Create my first circle',
      'Join an existing circle',
      'Just explore for now',
    ],
  ),
];
