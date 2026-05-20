-- Users may create their own profile row when the auth trigger did not run
-- (e.g. accounts predating the profiles table). Required for FK on comments.created_by.
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);
