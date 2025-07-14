import bcrypt from 'bcrypt';

const generateHash = async (password: string) => {
  const saltRounds = 10;
  
  try {
    const hash = await bcrypt.hash(password, saltRounds);
    console.log(`Password: ${password}`);
    console.log(`Hash: ${hash}`);
  } catch (error) {
    console.error('Error generating hash:', error);
  }
};

// Get password from command line arguments
const password = process.argv[2] || '123456';
generateHash(password);
