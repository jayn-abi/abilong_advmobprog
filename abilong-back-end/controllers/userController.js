const User = require("../models/User");
const jwt = require("jsonwebtoken");

// Get all users
const getUsers = async (req, res) => {
  try {
    const users = await User.find({}, "-password"); // Exclude password
    res.json({ users });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Create user (admin use)
const createUser = async (req, res) => {
  try {
    if (!req.body.password) {
      return res.status(400).json({ message: "Password is required" });
    }

    const user = new User(req.body); // password will be hashed in pre-save hook
    await user.save();

    const { password, ...userWithoutPassword } = user.toObject();
    res.status(201).json(userWithoutPassword);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Update user
const updateUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });

    // If password included, assign (will hash via pre-save)
    if (req.body.password) {
      user.password = req.body.password;
    }

    // Assign other fields
    Object.assign(user, req.body);

    await user.save();

    const token = jwt.sign(
      { id: user._id, email: user.email, type: user.type },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    const { password, ...userWithoutPassword } = user.toObject();
    res.json({ message: "User updated successfully", user: userWithoutPassword, token });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Update username
const updateUsername = async (req, res) => {
  try {
    const { username } = req.body;
    if (!username) return res.status(400).json({ message: "Username is required" });

    const existingUser = await User.findOne({ username, _id: { $ne: req.params.id } });
    if (existingUser) return res.status(409).json({ message: "Username already in use" });

    const user = await User.findByIdAndUpdate(req.params.id, { username }, { new: true }).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });

    res.json({ message: "Username updated successfully", user });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Change password
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });

    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) return res.status(400).json({ message: "Current password is incorrect" });

    user.password = newPassword; // will be hashed by pre-save
    await user.save();

    res.json({ message: "Password changed successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete user
const deleteUser = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: "User deleted successfully" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Login
const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (!user.isActive) {
      return res.status(403).json({ message: "Your account is inactive. Please contact support." });
    }

    const isPasswordValid = await user.matchPassword(password);
    if (!isPasswordValid) return res.status(401).json({ message: "Invalid credentials" });

    const token = jwt.sign(
      { id: user._id, email: user.email, type: user.type },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    const { password: pw, ...userWithoutPassword } = user.toObject();
    res.json({ message: "Login successful", token, user: userWithoutPassword });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Signup
const signupUser = async (req, res) => {
  try {
    const { firstName, lastName, email, username, password } = req.body;

    if (!firstName || !lastName || !email || !username || !password) {
      return res.status(400).json({ message: "Please fill in all required fields" });
    }

    const existingEmail = await User.findOne({ email });
    if (existingEmail) return res.status(409).json({ message: "Email already in use" });

    const existingUsername = await User.findOne({ username });
    if (existingUsername) return res.status(409).json({ message: "Username already in use" });

    const user = new User(req.body); // password will be hashed
    await user.save();

    const token = jwt.sign(
      { id: user._id, email: user.email, type: user.type },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    const { password: pw, ...userWithoutPassword } = user.toObject();
    res.status(201).json({ message: "Signup successful", user: userWithoutPassword, token });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getUsers,
  createUser,
  updateUser,
  deleteUser,
  loginUser,
  signupUser,
  updateUsername,
  changePassword,
};
