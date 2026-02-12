import { useNavigate } from "react-router-dom";
import LoginScreen from "@/components/LoginScreen";

interface LoginProps {
  onAuthenticated: () => void;
}

const Login = ({ onAuthenticated }: LoginProps) => {
  const navigate = useNavigate();

  const handleLogin = () => {
    onAuthenticated();
    navigate("/app", { replace: true });
  };

  return <LoginScreen onLogin={handleLogin} />;
};

export default Login;
