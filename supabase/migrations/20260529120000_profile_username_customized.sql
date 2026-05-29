-- Track whether the user has confirmed their public community display name.
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS username_customized BOOLEAN NOT NULL DEFAULT false;

-- Existing users keep their current username; do not re-prompt them.
UPDATE profiles SET username_customized = true WHERE username_customized = false;
