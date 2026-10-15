import backgroundImage from "@/assets/background/deep-teal-minimalist-curved-landscape-pexels-steve.webp";
import { Link } from "react-router-dom";

const ForgotPassword = () => (
  <div
    className="min-h-screen flex items-center justify-center bg-cover bg-center bg-no-repeat w-full relative"
    style={{ backgroundImage: `url(${backgroundImage})` }}
  >
    <div className="absolute inset-0 bg-foreground/50" />
    <div className="w-full max-w-md mx-auto py-8 px-4 sm:px-6 relative z-10">
      <div className="bg-card/95 backdrop-blur-sm border border-border/40 rounded-md overflow-hidden px-5 sm:px-8 pt-8 pb-10">
        <h2 className="text-center text-xl sm:text-2xl font-bold text-foreground mb-6">
          Recuperar contraseña
        </h2>
        <div className="text-center space-y-6">
          <p className="text-foreground">
            La recuperación por correo no está disponible en esta instalación.
            Contacta al administrador para obtener asistencia con tu cuenta.
            No se ha enviado ningún correo de recuperación.
          </p>
          <Link
            to="/Login"
            className="w-full flex justify-center items-center h-10 px-4 bg-primary text-primary-foreground text-sm font-semibold rounded-md hover:bg-primary/90 transition-colors"
          >
            Volver a Iniciar Sesión
          </Link>
        </div>
      </div>
    </div>
  </div>
);

export default ForgotPassword;
