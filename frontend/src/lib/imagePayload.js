/**
 * Include image_url only when the form has an image change to send.
 * An empty string means no image instruction (for a new form); null is the
 * explicit clear value required by the API.
 */
export const withImageUrl = (payload, imageUrl) => {
  if (imageUrl === undefined || imageUrl === '') return payload;
  return { ...payload, imageUrl };
};
