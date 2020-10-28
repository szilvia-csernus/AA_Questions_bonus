PRAGMA foreign_keys = ON;

DROP TABLE question_likes;
DROP TABLE question_follows;
DROP TABLE replies;
DROP TABLE questions;
DROP TABLE users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname VARCHAR(255) NOT NULL,
    lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body VARCHAR(255) NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    question_id INTEGER NOT NULL,
    follower_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (follower_id) REFERENCES users(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    parent_reply INTEGER,
    user_id INTEGER NOT NULL,
    body TEXT NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (parent_reply) REFERENCES replies(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
    question_id INTEGER NOT NULL,
    liker_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (liker_id) REFERENCES users(id)
);

INSERT INTO
    users (fname, lname)
VALUES
    (("Szilvi"), ("Csernusne")),
    (("Donald"), ("Trump")),
    (("Obama"), ("Barack")),
    (("Hilary"), ("Clinton")),
    (("Joe"), ("Biden"));

INSERT INTO
    questions (title, body, author_id)
VALUES
    (("Greatest president"), ("Who is the greatest president of all times?"), 1),
    (("Global warming"), ("What causes climate change?"), 1),
    (("Finland"), ("Is Finland a part of Russia?"), 2),
    (("Disinfectant"), ("Can we inject disinfectant into people as a cure for covid?"), 2),
    (("Real"),("Is Trump for real?"), 5);

INSERT INTO
    question_follows (question_id, follower_id)
VALUES
    (1, 2), (1, 4), (2, 2), (2, 3), (3, 1), (3, 3), (4, 1), (4, 3);

INSERT INTO
    replies (question_id, parent_reply, user_id, body)
VALUES
    (1, NULL, 2, ("Who is this asking that? Stupid question.")),
    (1, 1, 2, ("Of course, I AM.")),
    (1, 2, 3, ("Abraham Lincoln or George Washington I would say.")),
    (1, 3, 2, ("I don't know those guys, but I'm smarter.")),
    (5, NULL, 5,("Not for long!!!"));

INSERT INTO
    question_likes (question_id, liker_id)
VALUES
    (1, 2), (2, 3), (2, 4), (3, 1), (4, 4);
