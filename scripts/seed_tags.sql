-- Insert tags
INSERT INTO tags (name) VALUES
-- Style tags
('wordplay'), ('puns'), ('dad-humor'), ('one-liner'), ('clever'), ('silly'), ('groan-worthy'),
-- Subject tags
('science'), ('chemistry'), ('physics'), ('biology'), ('math'),
('food'), ('cooking'), ('pizza'), ('pasta'), ('cheese'), ('fruit'),
('animals'), ('dogs'), ('cats'), ('birds'), ('fish'), ('bears'),
('technology'), ('computers'), ('programming'),
('sports'), ('golf'), ('soccer'), ('basketball'),
('dad'), ('family'), ('meta')
ON CONFLICT (name) DO NOTHING;

-- Associate tags with jokes
-- Science jokes
INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t scientists trust atoms?' AND t.name IN ('wordplay', 'science', 'chemistry', 'dad-humor', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'I''m reading a book about anti-gravity.' AND t.name IN ('wordplay', 'science', 'physics', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why can''t you trust an atom?' AND t.name IN ('wordplay', 'science', 'chemistry', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did one DNA strand say to the other?' AND t.name IN ('wordplay', 'science', 'biology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the physicist go to the beach?' AND t.name IN ('wordplay', 'science', 'physics', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why was the math book sad?' AND t.name IN ('wordplay', 'math', 'silly', 'one-liner');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Parallel lines have so much in common.' AND t.name IN ('wordplay', 'math', 'clever', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did the thermometer say to the graduated cylinder?' AND t.name IN ('wordplay', 'science', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why are chemists excellent for solving problems?' AND t.name IN ('wordplay', 'science', 'chemistry', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call an educated tube?' AND t.name IN ('wordplay', 'science', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the germ cross the microscope?' AND t.name IN ('wordplay', 'science', 'biology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you do with a sick chemist?' AND t.name IN ('wordplay', 'science', 'chemistry', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What is a physicist''s favorite food?' AND t.name IN ('wordplay', 'science', 'physics', 'puns', 'food');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why can''t you trust atoms?' AND t.name IN ('wordplay', 'science', 'chemistry', 'meta');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did the biologist wear to impress?' AND t.name IN ('wordplay', 'science', 'biology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why do biologists look forward to casual Fridays?' AND t.name IN ('wordplay', 'science', 'biology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did one quantum physicist say when he wanted to fight another quantum physicist?' AND t.name IN ('wordplay', 'science', 'physics', 'puns');

-- Food jokes
INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a fake noodle?' AND t.name IN ('wordplay', 'food', 'pasta', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t eggs tell jokes?' AND t.name IN ('wordplay', 'food', 'puns', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Did you hear about the restaurant on the moon?' AND t.name IN ('wordplay', 'food', 'science', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the coffee file a police report?' AND t.name IN ('wordplay', 'food', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did the grape say when it got stepped on?' AND t.name IN ('wordplay', 'food', 'fruit', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the tomato turn red?' AND t.name IN ('wordplay', 'food', 'puns', 'one-liner');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call cheese that isn''t yours?' AND t.name IN ('wordplay', 'food', 'cheese', 'puns', 'classic');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the cookie go to the doctor?' AND t.name IN ('wordplay', 'food', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What''s orange and sounds like a parrot?' AND t.name IN ('wordplay', 'food', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t oysters donate to charity?' AND t.name IN ('wordplay', 'food', 'animals', 'fish', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a sad strawberry?' AND t.name IN ('wordplay', 'food', 'fruit', 'puns', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the banana go to the doctor?' AND t.name IN ('wordplay', 'food', 'fruit', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a sleeping pizza?' AND t.name IN ('wordplay', 'food', 'pizza', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the mushroom go to the party?' AND t.name IN ('wordplay', 'food', 'puns', 'classic');

-- Animal jokes
INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a bear with no teeth?' AND t.name IN ('wordplay', 'animals', 'bears', 'puns', 'classic');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a fish wearing a bowtie?' AND t.name IN ('wordplay', 'animals', 'fish', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t elephants use computers?' AND t.name IN ('wordplay', 'animals', 'technology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a pile of cats?' AND t.name IN ('wordplay', 'animals', 'cats', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why do cows have hooves instead of feet?' AND t.name IN ('wordplay', 'animals', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a dog magician?' AND t.name IN ('wordplay', 'animals', 'dogs', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t ants get sick?' AND t.name IN ('wordplay', 'animals', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a sleeping bull?' AND t.name IN ('wordplay', 'animals', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why do seagulls fly over the sea?' AND t.name IN ('wordplay', 'animals', 'birds', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a bear in the rain?' AND t.name IN ('wordplay', 'animals', 'bears', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t crabs give to charity?' AND t.name IN ('wordplay', 'animals', 'fish', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a parade of rabbits hopping backwards?' AND t.name IN ('wordplay', 'animals', 'puns');

-- Technology jokes
INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What''s a computer''s favorite snack?' AND t.name IN ('wordplay', 'technology', 'computers', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a computer that sings?' AND t.name IN ('wordplay', 'technology', 'computers', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the robot go on a diet?' AND t.name IN ('wordplay', 'technology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why do programmers prefer dark mode?' AND t.name IN ('wordplay', 'technology', 'programming', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the smartphone need glasses?' AND t.name IN ('wordplay', 'technology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a computer floating in the ocean?' AND t.name IN ('wordplay', 'technology', 'computers', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why was the computer cold?' AND t.name IN ('wordplay', 'technology', 'computers', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you get when you cross a computer with an elephant?' AND t.name IN ('wordplay', 'technology', 'computers', 'animals', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the PowerPoint presentation cross the road?' AND t.name IN ('wordplay', 'technology', 'puns', 'meta');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What''s a programmer''s favorite hangout place?' AND t.name IN ('wordplay', 'technology', 'programming', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why do Java developers wear glasses?' AND t.name IN ('wordplay', 'technology', 'programming', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did the router say to the doctor?' AND t.name IN ('wordplay', 'technology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why was the JavaScript developer sad?' AND t.name IN ('wordplay', 'technology', 'programming', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a programmer from Finland?' AND t.name IN ('wordplay', 'technology', 'programming', 'puns');

-- Sports jokes
INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the golfer bring two pairs of pants?' AND t.name IN ('wordplay', 'sports', 'golf', 'puns', 'classic');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why can''t basketball players go on vacation?' AND t.name IN ('wordplay', 'sports', 'basketball', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the soccer player bring string to the game?' AND t.name IN ('wordplay', 'sports', 'soccer', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a boomerang that doesn''t come back?' AND t.name IN ('wordplay', 'sports', 'clever', 'one-liner');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why was Cinderella so bad at soccer?' AND t.name IN ('wordplay', 'sports', 'soccer', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t tennis players ever get married?' AND t.name IN ('wordplay', 'sports', 'clever', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a snowman with a six-pack?' AND t.name IN ('wordplay', 'sports', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the bicycle fall over?' AND t.name IN ('wordplay', 'sports', 'puns', 'classic');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What lights up a soccer stadium?' AND t.name IN ('wordplay', 'sports', 'soccer', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t basketball players ever get hot?' AND t.name IN ('wordplay', 'sports', 'basketball', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the stadium get hot after the game?' AND t.name IN ('wordplay', 'sports', 'puns', 'clever');

-- Dad/General jokes
INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the scarecrow win an award?' AND t.name IN ('wordplay', 'puns', 'dad-humor', 'classic');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'I used to hate facial hair...' AND t.name IN ('wordplay', 'dad-humor', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a can opener that doesn''t work?' AND t.name IN ('wordplay', 'puns', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What''s the best thing about Switzerland?' AND t.name IN ('wordplay', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'I''m on a seafood diet.' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'puns', 'food');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What time did the man go to the dentist?' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'I told my wife she was drawing her eyebrows too high.' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'family', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What''s the best way to watch a fly fishing tournament?' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'technology', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the invisible man turn down the job offer?' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'I only know 25 letters of the alphabet.' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did the zero say to the eight?' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'math', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why do fathers take an extra pair of socks when they golf?' AND t.name IN ('wordplay', 'dad', 'family', 'sports', 'golf', 'puns', 'classic');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'I used to play piano by ear...' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a factory that makes okay products?' AND t.name IN ('wordplay', 'dad', 'dad-humor', 'puns');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t skeletons fight each other?' AND t.name IN ('wordplay', 'puns', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did one wall say to the other?' AND t.name IN ('wordplay', 'puns', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a man with a rubber toe?' AND t.name IN ('wordplay', 'puns', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the picture go to jail?' AND t.name IN ('wordplay', 'puns', 'silly');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What do you call a belt made of watches?' AND t.name IN ('wordplay', 'puns', 'clever');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why don''t some couples go to the gym?' AND t.name IN ('wordplay', 'puns', 'family');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'What did the ocean say to the beach?' AND t.name IN ('wordplay', 'puns', 'classic');

INSERT INTO joke_tags (joke_id, tag_id)
SELECT j.id, t.id FROM jokes j CROSS JOIN tags t
WHERE j.setup = 'Why did the hipster burn his mouth?' AND t.name IN ('wordplay', 'puns', 'clever', 'food');
