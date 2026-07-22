-- Migration: Add street_address column to profiles table
-- Run against Supabase Cloud after local schema update

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS street_address TEXT;
