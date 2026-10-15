export const requireSessionToken = (
  localStorageRef = globalThis.localStorage,
  sessionStorageRef = globalThis.sessionStorage,
) => {
  let token;
  try {
    token = localStorageRef?.getItem('token') || sessionStorageRef?.getItem('token');
  } catch {
    token = null;
  }

  if (!token) {
    throw Object.assign(new Error('Inicia sesión para realizar este cálculo.'), {
      code: 'UNAUTHORIZED',
    });
  }

  return token;
};

export default requireSessionToken;
