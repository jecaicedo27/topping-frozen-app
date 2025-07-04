import React, { createContext } from 'react';
import { UserContextType, UserRole } from '../types/user';

// Create context with default values
export const UserContext = createContext<UserContextType>({
  userRole: UserRole.ADMIN,
  setUserRole: () => {}
});

// Context Provider component
export const UserProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [userRole, setUserRole] = React.useState<UserRole>(UserRole.ADMIN);

  return (
    <UserContext.Provider value={{ userRole, setUserRole }}>
      {children}
    </UserContext.Provider>
  );
};

// Custom hook for using the context
export const useUser = () => {
  const context = React.useContext(UserContext);
  if (context === undefined) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return context;
};
