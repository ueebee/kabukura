defmodule Kabukura.Encryption do
  @moduledoc """
  Provides encryption and decryption functionality for sensitive data.
  """

  @type encrypted_data :: binary()
  @type iv :: binary()
  @type encryption_result :: {encrypted_data(), iv()}

  @doc """
  Encrypts the given data using AES-256-GCM.
  Returns a tuple with the encrypted data and the initialization vector.
  """
  @spec encrypt(binary()) :: {binary(), binary()} | no_return()
  def encrypt(data) when is_binary(data) do
    iv = :crypto.strong_rand_bytes(12)
    key = get_encryption_key()
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, data, "", 16, true)
    encrypted_data = iv <> tag <> ciphertext
    {encrypted_data, iv}
  end

  @doc """
  Decrypts the given encrypted data using AES-256-GCM.
  """
  @spec decrypt(encrypted_data()) :: binary()
  def decrypt(encrypted_data) when is_binary(encrypted_data) do
    key = get_encryption_key()
    <<iv::binary-12, tag::binary-16, ciphertext::binary>> = encrypted_data
    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, "", tag, false)
  end

  defp get_encryption_key do
    key = System.get_env("ENCRYPTION_KEY")
    if is_nil(key) do
      raise "ENCRYPTION_KEY environment variable is missing"
    end
    if byte_size(key) != 32 do
      raise "ENCRYPTION_KEY environment variable must be 32 bytes long"
    end
    key
  end
end
